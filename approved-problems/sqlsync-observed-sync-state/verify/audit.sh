#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TASK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BASE_SOURCE="${SQLSYNC_BASE_SOURCE:?set SQLSYNC_BASE_SOURCE to a pristine frozen checkout}"

check_hash() {
    local expected="$1"
    local file="$2"
    local actual
    actual="$(sha256sum "$file" | awk '{print $1}')"
    test "$actual" = "$expected"
    printf '%s  %s\n' "$actual" "${file#$TASK_DIR/}"
}

test "$(git -C "$BASE_SOURCE" rev-parse HEAD)" = \
    "7dc1af6b082023982fd2697f913f5b27453747f1"

check_hash 70aa414159f1f0a905168b9d29b66b194c5c01988a6fcf2cd76ed04d58c655d8 \
    "$TASK_DIR/meta.md"
check_hash 4d54b57df88ef10ff276a53d965295f3aa049221c9663259a7fdda72456e930a \
    "$TASK_DIR/test.patch"
check_hash a3540d437fc3dbe20cec4a812c1787439fe7a038f874c393ca2ee8be26fe7b2c \
    "$TASK_DIR/solution.patch"
check_hash fad98b2d344b5a052570d86aa9698751607523dedb1bc29506de1032f9e9addc \
    "$TASK_DIR/Dockerfile"

git -C "$BASE_SOURCE" apply --check "$TASK_DIR/test.patch"
git -C "$BASE_SOURCE" apply --check "$TASK_DIR/solution.patch"

test "$(wc -w <"$TASK_DIR/meta.md")" -le 500
if LC_ALL=C grep -n '[^ -~]' "$TASK_DIR/meta.md"; then
    echo "meta.md contains non-ASCII text" >&2
    exit 1
fi
if rg -n -i 'hidden|test\.patch|solution\.patch|mutant|reference solution' "$TASK_DIR/meta.md"; then
    echo "meta.md leaks construction terminology" >&2
    exit 1
fi
if rg -n 'Carry the same capability|Keep the four existing|camel-case field|current query|subscribed-database|await-until-applied|required private persistence' \
    "$TASK_DIR/meta.md"; then
    echo "meta.md retained removed non-functional scope prose" >&2
    exit 1
fi
if rg -n 'exact generated|generated `Lsn`' "$TASK_DIR/meta.md"; then
    echo "meta.md prescribes generated LSN provenance" >&2
    exit 1
fi
if rg -n 'documented lossless representation' "$TASK_DIR/meta.md"; then
    echo "meta.md retains an unverified documentation obligation" >&2
    exit 1
fi
rg -Fq 'any lossless representation is acceptable' "$TASK_DIR/meta.md"
for heading in \
    '## Rust API' \
    '## Progress semantics' \
    '## Receipt classification' \
    '## Worker and browser API' \
    '## Sync-state subscriptions' \
    '## Framework hooks'; do
    rg -Fq "$heading" "$TASK_DIR/meta.md"
done
rg -q 'public `timeline_id` and `lsn` fields' "$TASK_DIR/meta.md"
rg -q 'public `timeline_id`, `local`, `received`, and `applied` fields' "$TASK_DIR/meta.md"
rg -q 'may accept the receipt by value or shared reference' "$TASK_DIR/meta.md"
rg -q 'named `SyncStateSubscription`' "$TASK_DIR/meta.md"
rg -q 'current snapshot before the method resolves' "$TASK_DIR/meta.md"
rg -q 'unsubscribes itself from inside `handleState`' "$TASK_DIR/meta.md"
rg -Fq 'SQLSync.mutationStatus(docId, docType, receipt)' "$TASK_DIR/meta.md"
rg -Fq '`"local"`, `"received"`, `"applied"`, or `undefined`' "$TASK_DIR/meta.md"
if rg -n 'SyncState::new|interface MutationReceipt|interface SyncState|MutationAccepted|received_watermark|reply\.(receipt|state)' \
    "$TASK_DIR/test.patch"; then
    echo "test.patch contains an undocumented implementation constraint" >&2
    exit 1
fi
rg -q 'ReturnType<SQLSync\["mutate"\]>' "$TASK_DIR/test.patch"
rg -q 'ReturnType<SQLSync\["syncState"\]>' "$TASK_DIR/test.patch"
rg -q 'ReturnType<SQLSync\["mutationStatus"\]>' "$TASK_DIR/test.patch"
rg -q 'beforeAcknowledgement' "$TASK_DIR/test.patch"
rg -Fq 'activeApi.handle({ portId: 1, ...message })' "$TASK_DIR/test.patch"
if rg -n 'observed_sync_state\.portable\.mjs|PORTABLE_FACADE_PROBE' "$TASK_DIR/test.patch"; then
    echo "test.patch retained a synthetic passing facade fallback" >&2
    exit 1
fi
rg -q 'isDeepStrictEqual\(secondHighState\.received, firstHighState\.received\)' \
    "$TASK_DIR/test.patch"
if rg -n 'BigInt|[0-9]n|writeBigUInt64|readBigUInt64' "$TASK_DIR/test.patch"; then
    echo "test.patch contains a BigInt-specific LSN fixture or conversion" >&2
    exit 1
fi
if rg -n '900719925474099[0-9]' "$TASK_DIR/test.patch"; then
    echo "test.patch contains a decimal high-LSN fixture that can imply a string carrier" >&2
    exit 1
fi
rg -Fq 'Public LSN values are never decoded or compared to these objects' \
    "$TASK_DIR/test.patch"
rg -Fq 'WIRE_HIGH_A = Object.freeze({ high: 0x00200000, low: 0 })' \
    "$TASK_DIR/test.patch"
rg -Fq 'WIRE_HIGH_B = Object.freeze({ high: 0x00200000, low: 1 })' \
    "$TASK_DIR/test.patch"
rg -Fq 'WIRE_HIGH_C = Object.freeze({ high: 0x00200000, low: 2 })' \
    "$TASK_DIR/test.patch"
rg -Fq 'WIRE_UNSIGNED_HALF_A = Object.freeze({ high: 0x80000000, low: 0 })' \
    "$TASK_DIR/test.patch"
rg -Fq 'WIRE_UNSIGNED_HALF_B = Object.freeze({ high: 0x80000000, low: 1 })' \
    "$TASK_DIR/test.patch"
rg -q 'assertOpaqueFutureReceiptRoundTrips' "$TASK_DIR/test.patch"
rg -q 'lower fresh-connection acknowledgement replacing stale knowledge' \
    "$TASK_DIR/test.patch"
rg -q 'empty-following retained-prefix acknowledgement' "$TASK_DIR/test.patch"
rg -q 'mutation receipt and SyncState identify different timelines' \
    "$TASK_DIR/test.patch"
rg -q 'sqlsync-react exec tsc --noEmit' "$TASK_DIR/test.patch"
rg -q 'sqlsync-solid-js exec tsc --noEmit' "$TASK_DIR/test.patch"
rg -q 'observed_sync_state\.hooks\.types\.ts' "$TASK_DIR/test.patch"
rg -q 'observed_sync_state\.hooks\.register\.mjs' "$TASK_DIR/test.patch"
rg -q 'observed_sync_state\.hooks\.loader\.mjs' "$TASK_DIR/test.patch"
rg -q 'observed_sync_state\.hooks\.mjs' "$TASK_DIR/test.patch"
rg -Fq 'HOOK_RUNTIME_PROBE' "$TASK_DIR/test.patch"
rg -q 'mutation hook did not propagate the SQLSync receipt' "$TASK_DIR/test.patch"
rg -Fq 'assert!(first.timeline_id == timeline_id)' "$TASK_DIR/test.patch"
rg -Fq 'assert!(second.lsn == 1)' "$TASK_DIR/test.patch"
if rg -U -n 'assert_eq!\([\s\S]{0,100}(MutationReceipt|MutationStatus)' \
    "$TASK_DIR/test.patch"; then
    echo "test.patch requires comparison/debug traits on a public Rust type" >&2
    exit 1
fi
if rg -n 'state\.status\(accepted\)|mutation_receipt\(' "$TASK_DIR/test.patch"; then
    echo "test.patch retains a fixed owned-receipt status call" >&2
    exit 1
fi
rg -Fq -- '--features receipt-by-value' "$TASK_DIR/test.patch"
rg -Fq -- '--features receipt-by-reference' "$TASK_DIR/test.patch"
rg -Fq 'state.status(receipt(timeline_id, lsn))' "$TASK_DIR/test.patch"
rg -Fq 'state.status(&receipt(timeline_id, lsn))' "$TASK_DIR/test.patch"
rg -Fq 'Some(MutationStatus::Applied)' "$TASK_DIR/test.patch"
rg -Fq 'Some(MutationStatus::Received)' "$TASK_DIR/test.patch"
rg -Fq 'Some(MutationStatus::Local)' "$TASK_DIR/test.patch"
rg -Fq '.is_none()' "$TASK_DIR/test.patch"
rg -Fq 'local: None' "$TASK_DIR/test.patch"
rg -Fq 'status(&missing_local, timeline_id, 2).is_none()' "$TASK_DIR/test.patch"
rg -Fq 'run_status_checks' "$TASK_DIR/test.patch"
rg -Fq 'test-support/observed-sync-state-status/Cargo.toml' "$TASK_DIR/test.patch"
if rg -n 'sync_state\([^\n]*\)\.unwrap|opaqueLsn|changed the opaque LSN|returned a different value' \
    "$TASK_DIR/test.patch"; then
    echo "test.patch requires an undocumented wrapper or facade representation" >&2
    exit 1
fi
rg -q 'impl IntoSyncState for SyncState' "$TASK_DIR/test.patch"
rg -q 'impl IntoSyncState for Option<SyncState>' "$TASK_DIR/test.patch"
rg -q 'impl<E: Debug> IntoSyncState for Result<SyncState, E>' "$TASK_DIR/test.patch"
rg -q 'subscribeSyncState' "$TASK_DIR/test.patch"
rg -q 'SyncStateSubscription' "$TASK_DIR/test.patch"
rg -q 'subscription-local mutation observation' "$TASK_DIR/test.patch"
rg -q 'pushed acknowledgement observation before facade polling' \
    "$TASK_DIR/test.patch"
rg -q 'coordinator acknowledgement was discovered by polling before push' \
    "$TASK_DIR/test.patch"
rg -Fq 'function assertBrowserLsnIsNotNumber(value, label)' \
    "$TASK_DIR/test.patch"
rg -Fq 'assertBrowserLsnIsNotNumber(receipt.lsn, "mutation receipt LSN")' \
    "$TASK_DIR/test.patch"
rg -Fq 'assertBrowserLsnIsNotNumber(state.local, "local SyncState watermark")' \
    "$TASK_DIR/test.patch"
rg -Fq 'assertBrowserLsnIsNotNumber(state.received, "received SyncState watermark")' \
    "$TASK_DIR/test.patch"
rg -Fq 'assertBrowserLsnIsNotNumber(appliedState.applied, "applied-flow applied watermark")' \
    "$TASK_DIR/test.patch"
rg -Fq 'assertSameSyncState(initialObservedState, initialState, "initial subscription")' \
    "$TASK_DIR/test.patch"
rg -Fq 'assertSyncProgressAbsent(initialObservedState, "initial subscription callback")' \
    "$TASK_DIR/test.patch"
rg -Fq 'assertSyncProgressAbsent(initialState, "initial syncState snapshot")' \
    "$TASK_DIR/test.patch"
rg -Fq 'assertSameSyncState(lateObservedStates.at(-1), lateCurrentState, "late subscription")' \
    "$TASK_DIR/test.patch"
rg -q 'acknowledgement re-emitted an unchanged connection status' \
    "$TASK_DIR/test.patch"
rg -q 'browser classifier did not report the local mutation stage' \
    "$TASK_DIR/test.patch"
rg -q 'browser classifier did not report the received mutation stage' \
    "$TASK_DIR/test.patch"
rg -q 'assertOlderReceiptUsesInclusiveWatermarks' "$TASK_DIR/test.patch"
rg -Fq 'appliedReceipt,' "$TASK_DIR/test.patch"
rg -Fq '"received",' "$TASK_DIR/test.patch"
rg -Fq '"applied",' "$TASK_DIR/test.patch"
rg -q 'browser classifier accepted a foreign-timeline receipt' \
    "$TASK_DIR/test.patch"
rg -q 'browser classifier accepted a receipt above local progress' \
    "$TASK_DIR/test.patch"
rg -Fq 'receiptWith(receipt, receiptTimeline, firstHighState.received)' \
    "$TASK_DIR/test.patch"
rg -q 'SQLSync\.mutate returned from a reducer-rejected mutation' "$TASK_DIR/test.patch"
rg -q 'reducer-rejected mutation advanced browser-visible local progress' \
    "$TASK_DIR/test.patch"
rg -Fq 'slice(observationsBeforeRejectedMutation)' "$TASK_DIR/test.patch"
rg -q 'reducer-rejected mutation emitted subscription-local progress' \
    "$TASK_DIR/test.patch"
rg -Fq 'slice(observationsBeforeLowerReconnect)' "$TASK_DIR/test.patch"
rg -Fq 'slice(observationsBeforeEmptyFollowing)' "$TASK_DIR/test.patch"
rg -Fq 'slice(observationsBeforeEmptyZero)' "$TASK_DIR/test.patch"
rg -Fq 'slice(lateObservationsBeforeEmptyZero)' "$TASK_DIR/test.patch"
rg -q 'fresh empty-zero range replacing retained acknowledgement' \
    "$TASK_DIR/test.patch"
rg -Fq 'const observationsBeforeUnansweredReconnect = observedStates.length' \
    "$TASK_DIR/test.patch"
rg -q 'fresh connection awaiting its first peer range' "$TASK_DIR/test.patch"
rg -q 'reconnect intent erased acknowledgement before observing a peer range' \
    "$TASK_DIR/test.patch"
rg -q 'reconnect intent emitted unobserved acknowledgement progress' \
    "$TASK_DIR/test.patch"
rg -Fq 'function isAbsent(value)' "$TASK_DIR/test.patch"
rg -Fq 'isAbsent(emptyZeroState.received)' "$TASK_DIR/test.patch"
if rg -n '(\.local|\.received|\.applied) (===|!==) (undefined|null)' \
    "$TASK_DIR/test.patch"; then
    echo "test.patch pins an optional SyncState field to one JavaScript sentinel" >&2
    exit 1
fi
rg -q 'peer delivery during self-unsubscribe callback' "$TASK_DIR/test.patch"
rg -q 'self-unsubscribe suppressed or duplicated delivery to an active peer' \
    "$TASK_DIR/test.patch"
rg -Fq 'for (const subscription of [...subscriptions])' \
    "$TASK_DIR/solution.patch"
rg -Fq 'let workerRequestCount = 0' "$TASK_DIR/test.patch"
rg -Fq 'const workerActivities = []' "$TASK_DIR/test.patch"
rg -Fq 'const requestsBeforeIdleSubscription = workerRequestCount' \
    "$TASK_DIR/test.patch"
rg -q 'idle sync-state subscriptions polled the worker' "$TASK_DIR/test.patch"
rg -q 'second document subscription received the first document mutation' \
    "$TASK_DIR/test.patch"
rg -q 'first document subscription received the second document mutation' \
    "$TASK_DIR/test.patch"
rg -q 'remaining subscriber local mutation after peer unsubscribe' \
    "$TASK_DIR/test.patch"
rg -q 'unsubscribed sync-state listener received a later local mutation' \
    "$TASK_DIR/test.patch"
rg -q 'unsubscribed listener received a later coordinator acknowledgement' \
    "$TASK_DIR/test.patch"
rg -q 'unsubscribed listener received a later applied-progress change' \
    "$TASK_DIR/test.patch"
rg -Fq 'const removedAppliedObservationsBeforeApplication = removedAppliedObservedStates.length' \
    "$TASK_DIR/test.patch"
rg -Fq 'activeWorker.holdNextDocumentRequest()' "$TASK_DIR/test.patch"
rg -Fq 'await activeWorker.releaseHeldDocumentRequest()' "$TASK_DIR/test.patch"
rg -q 'initial subscription replayed a superseded registration-time snapshot' \
    "$TASK_DIR/test.patch"
rg -Fq 'resumedObservedStates[0].local, registrationNewestReceipt.lsn' \
    "$TASK_DIR/test.patch"
rg -q 'browser classifier did not apply the inclusive received watermark' \
    "$TASK_DIR/test.patch"
rg -q 'browser classifier did not apply the inclusive local watermark' \
    "$TASK_DIR/test.patch"
rg -q 'registering a peer subscription notified an existing subscription' \
    "$TASK_DIR/test.patch"
rg -Fq 'const observationsBeforePeerTeardown = observedStates.length' \
    "$TASK_DIR/test.patch"
rg -Fq 'const lateObservationsBeforePeerTeardown = lateObservedStates.length' \
    "$TASK_DIR/test.patch"
rg -Fq 'unsubscribeTeardownSyncState()' "$TASK_DIR/test.patch"
rg -q 'removing a peer subscription notified an active subscription' \
    "$TASK_DIR/test.patch"
rg -q 'reducer-rejected mutation emitted a sync-state callback' \
    "$TASK_DIR/test.patch"
rg -Fq 'accepted_after_failure.lsn == accepted.lsn + 1' \
    "$TASK_DIR/test.patch"
rg -q 'subscription first high-LSN observation after unanswered reconnect' \
    "$TASK_DIR/test.patch"
if rg -Fq 'setTimeout(resolveWait, 25)' "$TASK_DIR/test.patch"; then
    echo "test.patch retains scheduler-sensitive 25ms negative callback waits" >&2
    exit 1
fi
rg -Fq 'unsubscribeLateSyncState()' "$TASK_DIR/test.patch"
rg -Fq 'WIRE_NEAR_U64_MAX = Object.freeze({ high: 0xffffffff, low: 0xfffffffe })' \
    "$TASK_DIR/test.patch"
rg -q 'near-u64-maximum acknowledgement observation' "$TASK_DIR/test.patch"
rg -q 'near-u64-maximum received watermark' "$TASK_DIR/test.patch"
if rg -Fq 'Object.freeze({ high: 0xffffffff, low: 0xffffffff })' \
    "$TASK_DIR/test.patch"; then
    echo "test.patch injects an upstream-unrepresentable u64::MAX range" >&2
    exit 1
fi
rg -Fq 'status(&received_state, timeline_id, 3)' "$TASK_DIR/test.patch"
rg -Fq 'status(&received_state, timeline_id, 4)' "$TASK_DIR/test.patch"
rg -Fq 'IsOptionalLsn<SyncState["local"]>' "$TASK_DIR/test.patch"
rg -Fq 'IsOptionalLsn<SyncState["received"]>' "$TASK_DIR/test.patch"
rg -Fq 'IsOptionalLsn<SyncState["applied"]>' "$TASK_DIR/test.patch"
rg -Fq 'const appliedResult: Lsn | null | undefined = exportedState.applied' \
    "$TASK_DIR/test.patch"
rg -Fq 'Equal<IsAny<MutationReceipt>, false>' "$TASK_DIR/test.patch"
rg -Fq 'Equal<IsAny<SyncState>, false>' "$TASK_DIR/test.patch"
rg -Fq 'Equal<IsAny<MutationStatus>, false>' "$TASK_DIR/test.patch"
rg -Fq 'Equal<MutationStatus, "local" | "received" | "applied">' \
    "$TASK_DIR/test.patch"
rg -Fq 'Equal<Parameters<SubscriptionHandler>, [SyncState]>' \
    "$TASK_DIR/test.patch"
rg -Fq 'TimelineField<MutationReceipt> extends DocId' \
    "$TASK_DIR/test.patch"
if rg -n '"applied" in|omits its applied field' "$TASK_DIR/test.patch"; then
    echo "test.patch requires optional applied fields to exist as runtime keys" >&2
    exit 1
fi
rg -q 'coordinator receipt before application' "$TASK_DIR/test.patch"
rg -q 'applied watermark advanced before coordinator application was visible' \
    "$TASK_DIR/test.patch"
rg -q 'worker applied watermark after coordinator application and rebase' \
    "$TASK_DIR/test.patch"
rg -Fq 'slice(observationsBeforeAppliedReturn)' "$TASK_DIR/test.patch"
rg -q 'subscription applied observation after coordinator application and rebase' \
    "$TASK_DIR/test.patch"
rg -q 'browser classifier accepted a receipt without local progress' \
    "$TASK_DIR/test.patch"
rg -q 'mixed applied and received watermarks for successive mutations' \
    "$TASK_DIR/test.patch"
rg -q 'mutation after rebase reused the applied prefix LSN' \
    "$TASK_DIR/test.patch"
rg -q 're-established subscription acknowledgement observation' \
    "$TASK_DIR/test.patch"
rg -Fq 'assert!(next_receipt.lsn == receipt_lsn + 1)' \
    "$TASK_DIR/test.patch"
rg -q 'fn applied_progress_is_bound_to_snapshot_timeline' "$TASK_DIR/test.patch"
rg -Fq 'assert_eq!(state.timeline_id, timeline_b)' "$TASK_DIR/test.patch"
rg -Fq 'unsubscribeAppliedSyncState()' "$TASK_DIR/test.patch"
rg -q 'example observed-sync-state-coordinator' "$TASK_DIR/test.patch"
rg -q 'self-unsubscribing listener did not receive exactly the current change' \
    "$TASK_DIR/test.patch"
rg -q 'BROWSER_PROBE' "$TASK_DIR/test.patch"
rg -q 'for tool in node pnpm wasm-pack' "$TASK_DIR/test.patch"
rg -q 'node lib/sqlsync-worker/tests/observed_sync_state\.mjs' "$TASK_DIR/test.patch"
rg -q 'cargo test --locked --offline --workspace --all-features --lib' "$TASK_DIR/test.patch"
rg -q 'doctest = false' "$TASK_DIR/test.patch"
rg -Fq 'run_mode 2>&1 | tee "$RUN_LOG"' "$TASK_DIR/test.patch"
rg -Fq 'STATUS="${PIPESTATUS[0]}"' "$TASK_DIR/test.patch"
rg -Fq "LC_ALL=C tr -cd '\\11\\12\\15\\40-\\176'" "$TASK_DIR/test.patch"
rg -Fq "sed -e 's/&/\\&amp;/g' -e 's/</\\&lt;/g' -e 's/>/\\&gt;/g'" \
    "$TASK_DIR/test.patch"
rg -Fq '<system-out>$XML_LOG</system-out>' "$TASK_DIR/test.patch"
rg -Fq 'grep -q "<system-out>" /tmp/report.xml' "$TASK_DIR/verify/gates.sh"
rg -Fq 'grep -q "HOOK_RUNTIME_PROBE" /tmp/report.xml' "$TASK_DIR/verify/gates.sh"
rg -Fq 'grep -q "BROWSER_PROBE" /tmp/report.xml' "$TASK_DIR/verify/gates.sh"
rg -Fq 'required browser integration tool is missing: pnpm' \
    "$TASK_DIR/verify/gates.sh"
if rg -n '(<skipped|skipped=|echo [^\n]*SKIP)' "$TASK_DIR/test.patch"; then
    echo "test.patch contains a skipped new-test path" >&2
    exit 1
fi
if rg -n 'cargo \+1\.91\.1|just unit-test|cargo nextest' "$TASK_DIR/test.patch"; then
    echo "test.patch retained evaluator-specific baseline commands" >&2
    exit 1
fi

test "$(git -C "$BASE_SOURCE" apply --numstat "$TASK_DIR/test.patch" | wc -l | tr -d ' ')" -eq 12
test "$(git -C "$BASE_SOURCE" apply --numstat "$TASK_DIR/solution.patch" | wc -l | tr -d ' ')" -eq 14

test "$(sed -n '1p' "$TASK_DIR/Dockerfile")" = \
    'FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest'
rg -q 'cargo-nextest --version 0\.9\.128' "$TASK_DIR/Dockerfile"
rg -q 'wasm-bindgen-cli --version 0\.2\.105' "$TASK_DIR/Dockerfile"
rg -q 'pnpm@9\.15\.9' "$TASK_DIR/Dockerfile"
rg -Fq 'clang=1:14.0-55.7~deb12u1' "$TASK_DIR/Dockerfile"
rg -Fq 'rustup target add wasm32-unknown-unknown --toolchain 1.91.1' \
    "$TASK_DIR/Dockerfile"
if rg -n 'rustup toolchain install[^\n]*--target|apt-get install[^\n]*(ca-certificates|curl|nodejs|pkg-config)' \
    "$TASK_DIR/Dockerfile"; then
    echo "Dockerfile retained the rejected install forms" >&2
    exit 1
fi
rg -q 'command -v pnpm' "$TASK_DIR/Dockerfile"
rg -q 'rustup target list --installed' "$TASK_DIR/Dockerfile"
rg -q 'cargo build --workspace --all-features --locked' "$TASK_DIR/Dockerfile"
rg -q 'cargo build --package sqlsync --lib --locked' "$TASK_DIR/Dockerfile"
rg -q 'test -f target/debug/deps/libsqlsync\.rlib' "$TASK_DIR/Dockerfile"
rg -q 'test -f pnpm-lock\.yaml && pnpm install --frozen-lockfile' "$TASK_DIR/Dockerfile"
if rg -n '^RUN +(just +test|cargo +(test|nextest)|pnpm +[^ ]*test|node +[^ ]*test)' \
    "$TASK_DIR/Dockerfile"; then
    echo "Dockerfile runs tests during image construction" >&2
    exit 1
fi

bash -n "$TASK_DIR/verify/gates.sh"
bash -n "$TASK_DIR/verify/mutations.sh"
rg -Fq 'olympus-sqlsync-observed-base:v24' "$TASK_DIR/verify/gates.sh"

echo "audit: pass"
