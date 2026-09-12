Title: Distinguish local and external hierarchical transitions

Add `Outcome::LocalTransition(S)` and `Outcome::ExternalTransition(S)` to Statig's blocking and awaitable state machines. Keep the deprecated `Response<S>` alias usable with every outcome.

A local transition follows the deepest common boundary of the active and target leaves, regardless of which handler accepted the event. Distinct leaf variants therefore use the current shortest path. A local transition to the same leaf variant runs no exit or entry action, but it must still replace the active leaf value so new state-local storage becomes observable.

An external transition uses the handler that actually returned it as its source boundary. Subtree membership follows that handler's hierarchy position; another occurrence of the same superstate variant is not the same boundary. If a superstate handler returns an external transition to a leaf that remains below that handler after handling, the handler still exits and re-enters even if a new parent was inserted above it; the new parent remains active. If the target is outside the accepting handler's subtree, use the ordinary deepest-common-ancestor path instead of widening past unrelated ancestors. An external transition returned directly by the active leaf must match legacy transition behavior, including leaf self-transition exit and re-entry.
