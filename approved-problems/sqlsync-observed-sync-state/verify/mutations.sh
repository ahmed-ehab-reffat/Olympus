#!/usr/bin/env bash

set -euo pipefail

IMAGE="${SQLSYNC_VERIFY_IMAGE:-olympus-sqlsync-observed-base:v15}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TASK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_ROOT="$(mktemp -d /tmp/sqlsync-mutations.XXXXXX)"

mutations=(
    local_last
    applied_is_received
    no_timeline_identity
    no_future_bound
    sent_is_received
    js_number
    stale_reconnect
    monotonic_max_reconnect
    reset_disconnect
    empty_ack_last_only
    lossy_string
    receipt_wrong_timeline
    facade_void_mutate
    facade_missing_sync_state
    hook_void_mutate
    subscription_no_current
    subscription_no_local_events
    subscription_no_ack_events
    subscription_no_unsubscribe
)

variations=(
    clone_facade_values
    rename_worker_schema
    rename_ack_accessor
    receipt_not_copy
    direct_sync_state
    transform_facade_lsn
    inferred_hook_receipt
    rename_subscription_schema
)

apply_mutation() {
    local mutation="$1"

    case "$mutation" in
        local_last)
            perl -pi -e \
                's/self\.timeline\.range\(\)\.watermark\(\)/self.timeline.range().last()/' \
                lib/sqlsync/src/local.rs
            ;;
        applied_is_received)
            perl -pi -e \
                's/applied_lsn\(&self\.sqlite\.readonly, self\.timeline\.id\(\)\)\?/received/' \
                lib/sqlsync/src/local.rs
            ;;
        no_timeline_identity)
            perl -pi -e \
                's/receipt\.timeline_id != self\.timeline_id/false/' \
                lib/sqlsync/src/sync.rs
            ;;
        no_future_bound)
            perl -pi -e \
                's/self\.local\.is_none_or\(\|local\| receipt\.lsn > local\)/false/' \
                lib/sqlsync/src/sync.rs
            ;;
        sent_is_received)
            perl -0pi -e \
                's/self\.outstanding_range = Some\(outstanding_range\.append\(lsn\)\);/self.outstanding_range = Some(outstanding_range.append(lsn));\n                self.destination_range = self.outstanding_range;/' \
                lib/sqlsync/src/replication.rs
            ;;
        js_number)
            perl -pi -e 's/export type Lsn = string/export type Lsn = number/' \
                lib/sqlsync-worker/sqlsync-wasm/src/api.rs
            ;;
        stale_reconnect)
            perl -0pi -e \
                's/if let Some\(range\) = state\.destination_range\(\)\.or\(range_before\) \{\n            self\.destination_range = Some\(range\);\n        \}/if self.destination_range.is_none() {\n            if let Some(range) = state.destination_range().or(range_before) {\n                self.destination_range = Some(range);\n            }\n        }/' \
                lib/sqlsync-worker/sqlsync-wasm/src/net.rs
            ;;
        monotonic_max_reconnect)
            perl -0pi -e \
                's/self\.destination_range = Some\(range\);/if range.watermark() >= self.destination_range.and_then(|known| known.watermark()) {\n                self.destination_range = Some(range);\n            }/' \
                lib/sqlsync-worker/sqlsync-wasm/src/net.rs
            ;;
        reset_disconnect)
            perl -0pi -e \
                's/        let range_before = state\.destination_range\(\);\n\n//' \
                lib/sqlsync-worker/sqlsync-wasm/src/net.rs
            perl -0pi -e \
                's/if let Some\(range\) = state\.destination_range\(\)\.or\(range_before\) \{\n            self\.destination_range = Some\(range\);\n        \}/self.destination_range = state.destination_range();/' \
                lib/sqlsync-worker/sqlsync-wasm/src/net.rs
            ;;
        empty_ack_last_only)
            perl -pi -e \
                's/self\.destination_range\.and_then\(\|range\| range\.watermark\(\)\)/self.destination_range.and_then(|range| range.last())/' \
                lib/sqlsync-worker/sqlsync-wasm/src/net.rs
            ;;
        lossy_string)
            perl -pi -e \
                's/receipt\.lsn\.to_string\(\)/(receipt.lsn as f64).to_string()/; s/lsn\.to_string\(\)/(lsn as f64).to_string()/g' \
                lib/sqlsync-worker/sqlsync-wasm/src/api.rs
            ;;
        receipt_wrong_timeline)
            perl -pi -e \
                's/timeline_id: receipt\.timeline_id/timeline_id: JournalId::try_from(vec![0; 16]).expect("valid fabricated timeline")/' \
                lib/sqlsync-worker/sqlsync-wasm/src/api.rs
            ;;
        facade_void_mutate)
            perl -pi -e \
                's/Promise<MutationReceipt>/Promise<void>/' \
                lib/sqlsync-worker/src/sqlsync.ts
            perl -pi -e \
                's/const reply = await this\.#send\("MutationAccepted"/await this.#send("MutationAccepted"/' \
                lib/sqlsync-worker/src/sqlsync.ts
            perl -0pi -e \
                's/    return reply\.receipt;\n//' \
                lib/sqlsync-worker/src/sqlsync.ts
            ;;
        facade_missing_sync_state)
            perl -0pi -e \
                's/\n  async syncState<M>\(docId: DocId, docType: DocType<M>\): Promise<SyncState> \{\n.*?\n  \}\n\n  get connectionStatus/\n  get connectionStatus/s' \
                lib/sqlsync-worker/src/sqlsync.ts
            ;;
        hook_void_mutate)
            perl -pi -e 's/Promise<MutationReceipt>/Promise<void>/' \
                lib/sqlsync-react/src/hooks.ts lib/sqlsync-solid-js/src/hooks.ts
            perl -0pi -e 's/  MutationReceipt,\n//' \
                lib/sqlsync-react/src/hooks.ts lib/sqlsync-solid-js/src/hooks.ts
            perl -pi -e \
                's/sqlsync\.mutate\(docId, docType, mutation\)/sqlsync.mutate(docId, docType, mutation).then(() => undefined)/' \
                lib/sqlsync-react/src/hooks.ts
            perl -pi -e \
                's/sqlsync\(\)\.mutate\(docId, docType\(\), mutation\)/sqlsync().mutate(docId, docType(), mutation).then(() => undefined)/' \
                lib/sqlsync-solid-js/src/hooks.ts
            ;;
        subscription_no_current)
            perl -pi -e \
                's/      subscription\.handleState\(state\);/      void state;/' \
                lib/sqlsync-worker/src/sqlsync.ts
            ;;
        subscription_no_local_events)
            perl -0pi -e \
                's/(Signal::TimelineChanged => \{\n                    self\.handle_timeline_changed\(\)\.await;)\n                    self\.handle_sync_state_changed\(\);\n                \}/$1\n                }/' \
                lib/sqlsync-worker/sqlsync-wasm/src/doc_task.rs
            ;;
        subscription_no_ack_events)
            perl -pi -e \
                's/status != new_status \|\| self\.destination_range != observation_before/status != new_status/' \
                lib/sqlsync-worker/sqlsync-wasm/src/net.rs
            ;;
        subscription_no_unsubscribe)
            perl -0pi -e \
                's/subscriptions\.splice\(idx, 1\);\n      if \(subscriptions\.length === 0\)/void idx;\n      if (subscriptions.length === 0)/' \
                lib/sqlsync-worker/src/sqlsync.ts
            ;;
        *)
            echo "unknown mutation: $mutation" >&2
            return 2
            ;;
    esac
}

apply_variation() {
    local variation="$1"

    case "$variation" in
        clone_facade_values)
            perl -pi -e \
                's/return reply\.receipt;/return { ...reply.receipt };/; s/return reply\.state;/return { ...reply.state };/; s/subscription\.handleState\(evt\.state\)/subscription.handleState({ ...evt.state })/' \
                lib/sqlsync-worker/src/sqlsync.ts
            ;;
        rename_worker_schema)
            perl -0pi -e \
                's/    SyncState,\n    RefreshConnectionStatus,/    ObserveState,\n    RefreshConnectionStatus,/; s/    MutationAccepted \{\n        receipt: MutationReceipt,\n    \},\n    SyncState \{\n        state: SyncState,\n    \},/    MutationStored {\n        value: MutationReceipt,\n    },\n    StateObserved {\n        value: SyncState,\n    },/' \
                lib/sqlsync-worker/sqlsync-wasm/src/api.rs
            perl -pi -e \
                's/^    SyncState,$/    ObserveState,/' \
                lib/sqlsync-worker/sqlsync-wasm/src/api.rs
            perl -0pi -e \
                's/DocReply::MutationAccepted \{ receipt: receipt\.into\(\) \}/DocReply::MutationStored { value: receipt.into() }/; s/DocRequest::SyncState => Ok\(DocReply::SyncState \{\n                state:/DocRequest::ObserveState => Ok(DocReply::StateObserved {\n                value:/' \
                lib/sqlsync-worker/sqlsync-wasm/src/doc_task.rs
            perl -pi -e \
                's/DocRequest::SyncState\b/DocRequest::ObserveState/g; s/DocReply::SyncState \{ state:/DocReply::StateObserved { value:/g' \
                lib/sqlsync-worker/sqlsync-wasm/src/doc_task.rs
            perl -pi -e \
                's/#send\("MutationAccepted"/#send("MutationStored"/g; s/return reply\.receipt;/return reply.value;/g; s/#send\("SyncState"/#send("StateObserved"/g; s/req: \{ tag: "SyncState" \}/req: { tag: "ObserveState" }/g; s/return reply\.state;/return reply.value;/g; s/\)\.state/).value/g' \
                lib/sqlsync-worker/src/sqlsync.ts
            ;;
        rename_ack_accessor)
            grep -RIl 'received_watermark' lib/sqlsync lib/sqlsync-worker | \
                xargs perl -pi -e 's/received_watermark/acknowledged_lsn/g'
            ;;
        receipt_not_copy)
            perl -pi -e \
                's/#\[derive\(Clone, Copy, Debug, PartialEq, Eq\)\]/#[derive(Clone, Debug, PartialEq, Eq)]/' \
                lib/sqlsync/src/sync.rs
            ;;
        direct_sync_state)
            perl -pi -e \
                's/pub fn sync_state\(&self, received: Option<Lsn>\) -> Result<SyncState>/pub fn sync_state(&self, received: Option<Lsn>) -> SyncState/' \
                lib/sqlsync/src/local.rs
            perl -0pi -e \
                's/(pub fn sync_state.*?\{\n)        Ok\(SyncState::new\(/$1        SyncState::new(/s; s/(pub fn sync_state.*?applied_lsn\(&self\.sqlite\.readonly, self\.timeline\.id\(\)\))\?,/$1.expect("applied progress should be readable"),/s; s/(pub fn sync_state.*?)(        \)\)\n    \})/$1        )\n    }/s' \
                lib/sqlsync/src/local.rs
            perl -pi -e \
                's/sync_state\(self\.coordinator_client\.received_watermark\(\)\)\?/sync_state(self.coordinator_client.received_watermark())/' \
                lib/sqlsync-worker/sqlsync-wasm/src/doc_task.rs
            perl -pi -e \
                's/sync_state\((None|received)\)\?/sync_state($1)/g' \
                lib/sqlsync/examples/end-to-end-local.rs
            ;;
        transform_facade_lsn)
            perl -pi -e 's/export type Lsn = string/export type Lsn = bigint/' \
                lib/sqlsync-worker/sqlsync-wasm/src/api.rs
            perl -pi -e \
                's/return reply\.receipt;/return { ...reply.receipt, lsn: BigInt(reply.receipt.lsn) };/' \
                lib/sqlsync-worker/src/sqlsync.ts
            perl -0pi -e \
                's/return reply\.state;/return {\n      ...reply.state,\n      local: reply.state.local === undefined ? undefined : BigInt(reply.state.local),\n      received: reply.state.received === undefined ? undefined : BigInt(reply.state.received),\n      applied: reply.state.applied === undefined ? undefined : BigInt(reply.state.applied),\n    };/' \
                lib/sqlsync-worker/src/sqlsync.ts
            perl -0pi -e \
                's/subscription\.handleState\(evt\.state\);/subscription.handleState({\n            ...evt.state,\n            local: evt.state.local === undefined ? undefined : BigInt(evt.state.local),\n            received: evt.state.received === undefined ? undefined : BigInt(evt.state.received),\n            applied: evt.state.applied === undefined ? undefined : BigInt(evt.state.applied),\n          });/' \
                lib/sqlsync-worker/src/sqlsync.ts
            ;;
        inferred_hook_receipt)
            perl -pi -e \
                's/type MutateFn<M> = \(mutation: M\) => Promise<MutationReceipt>;/type MutateFn<M> = (mutation: M) => ReturnType<SQLSync["mutate"]>;/' \
                lib/sqlsync-react/src/hooks.ts lib/sqlsync-solid-js/src/hooks.ts
            perl -0pi -e 's/  MutationReceipt,\n//' \
                lib/sqlsync-react/src/hooks.ts lib/sqlsync-solid-js/src/hooks.ts
            ;;
        rename_subscription_schema)
            perl -pi -e \
                's/SyncStateSubscribe/ObserveStateSubscribe/g; s/SyncStateUnsubscribe/ObserveStateUnsubscribe/g; s/SyncStateChanged/ObservedState/g' \
                lib/sqlsync-worker/sqlsync-wasm/src/api.rs \
                lib/sqlsync-worker/sqlsync-wasm/src/doc_task.rs \
                lib/sqlsync-worker/src/sqlsync.ts
            ;;
        *)
            echo "unknown variation: $variation" >&2
            return 2
            ;;
    esac
}

run_one() {
    local case_kind="$1"
    local case_name="$2"
    local log="$LOG_ROOT/$case_kind-$case_name.log"

    set +e
    docker run --rm --platform linux/amd64 --network none \
        -v "$TASK_DIR:/patches:ro" \
        -v "$SCRIPT_DIR/mutations.sh:/mutation-runner:ro" \
        "$IMAGE" \
        /bin/bash /mutation-runner "--inside-$case_kind" "$case_name" >"$log" 2>&1
    local status="$?"
    set -e

    printf '%s %s: %s\n' "$case_kind" "$case_name" "$status"
    tail -n 8 "$log"
    return "$status"
}

if [ "${1-}" = "--inside-mutant" ] || [ "${1-}" = "--inside-variation" ]; then
    inside_mode="$1"
    case_name="${2:?missing case name}"
    cd /app
    git apply /patches/solution.patch
    git apply /patches/test.patch
    before_hash="$(find lib/sqlsync lib/sqlsync-worker lib/sqlsync-react lib/sqlsync-solid-js \
        -type f -print0 | \
        sort -z | xargs -0 sha256sum | sha256sum)"
    if [ "$inside_mode" = "--inside-mutant" ]; then
        apply_mutation "$case_name"
    else
        apply_variation "$case_name"
    fi
    after_hash="$(find lib/sqlsync lib/sqlsync-worker lib/sqlsync-react lib/sqlsync-solid-js \
        -type f -print0 | \
        sort -z | xargs -0 sha256sum | sha256sum)"
    test "$before_hash" != "$after_hash"

    set +e
    ./test.sh --output_path /tmp/case.xml new
    case_status="$?"
    set -e

    test -s /tmp/case.xml
    if [ "$inside_mode" = "--inside-mutant" ]; then
        test "$case_status" -ne 0
        grep -q 'failures="1"' /tmp/case.xml
    else
        test "$case_status" -eq 0
        grep -q 'failures="0"' /tmp/case.xml
    fi
    exit 0
fi

case_kind="mutant"
if [ "${1-}" = "--variations" ]; then
    case_kind="variation"
    shift
fi

requested=("$@")
if [ "${#requested[@]}" -eq 0 ]; then
    if [ "$case_kind" = "mutant" ]; then
        requested=("${mutations[@]}")
    else
        requested=("${variations[@]}")
    fi
fi

overall=0
for case_name in "${requested[@]}"; do
    if ! run_one "$case_kind" "$case_name"; then
        overall=1
    fi
done

printf 'logs: %s\n' "$LOG_ROOT"
exit "$overall"
