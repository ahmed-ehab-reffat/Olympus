---
Repository: https://github.com/cschleiden/go-workflows
Issue: N/A
Commit: 48e811947bece0a2a9993d85edcf9a0f3a7e486b
Language: Go
Category: feature-request
Title: Add draining and overflow control to workflow channels
---

# Add draining and overflow control to workflow channels

Add bulk draining, non-destructive peeking, and configurable overflow handling to `workflow.Channel`.

`Channel.Drain` removes and returns every value the channel can currently provide without blocking: buffered values and values held by coroutines currently blocked sending to the channel, in the order they became available. A blocked sender's value became available when it blocked, so it precedes anything sent later. Freeing room does not hand that room to a coroutine already blocked sending: a send arriving before that coroutine resumes takes the room, and still orders behind it. Draining must not strand a coroutine: a blocked sender whose value Drain took, and a send case waiting on room Drain freed, both resume before the scheduler run that drained them finishes, with no further channel activity needed. `Channel.Peek`, `PeekN`, and `PeekAll` return the same values without removing them; `PeekN` returns up to n.

All return empty immediately when nothing is available, open or closed. `workflow.Drain` is a new `Select` case, ready whenever `Receive` would be, whose handler receives everything `Drain` would; a value arriving while such a case waits must also run it.

`workflow.SelectAll` handles every case still ready when it is reached, in the order given, returning how many it handled. Every `Default` case fires, in that same order, only if none of the others were ready; with no `Default` and nothing ready, `SelectAll` waits like `Select`.

`workflow.NewBufferedChannelWithPolicy` creates a buffered channel with an explicit overflow policy, panicking on negative size. `workflow.NewSignalChannel` accepts the same policy through `WithSignalChannelOverflowPolicy`. The default `OverflowBlock` waits for room on a blocking send. A non-blocking send that finds no room is lost, counted like an `OverflowDropOldest` eviction. `Channel.DroppedCount` reports how many were lost this way.

`workflow.NewSignalChannel` also accepts `WithSignalChannelCapacity` to size the buffer; omitting it uses the existing default capacity. Signals delivered before that name has a channel are replayed in arrival order once created. Replay never blocks: the channel's overflow policy applies exactly as to a live delivery.

`Channel.CloseDraining` closes a channel and returns any values still present. Draining frees a coroutine blocked sending one of those values, but not a send case waiting for room; closing while one waits panics as `Close` does. `Channel.TryCloseDraining` instead reports the remaining values and `false`, changing nothing, whenever any coroutine is blocked sending. A coroutine the scheduler tears down is not blocked sending, and its value is not available. `Channel.Closed` reports whether the channel is closed. `workflow.PendingSignalNames` returns the signal names delivered with no channel created yet, and `HasPendingSignal` whether a name is among them.

`workflow.DrainAll` and `PeekAllChannels` apply `Drain` or `PeekAll` across several channels, concatenating their values in channel order. `Channel.SendAllNonblocking` sends as many values from a slice as fit, stopping at the first that does not, and returns how many were sent. `Channel.Cap` reports a channel's buffered capacity, `Channel.IsFull` whether it is currently at that capacity (an unbuffered channel is always full), and `workflow.SignalChannelDroppedCount` reports a signal channel's drop count by name, or 0 if none exists yet.
