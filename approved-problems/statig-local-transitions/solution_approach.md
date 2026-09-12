# Solution approach - handler-aware transition boundaries

## Private dispatch metadata

`Outcome<S>` gains public `LocalTransition(S)` and `ExternalTransition(S)`
variants, while transition classification and handler depth remain
crate-private. The existing public `StateExt::handle` and
`SuperstateExt::handle` signatures still return only `Outcome`; their exhaustive
matches merely propagate the new variants.

Each private `Inner` engine now dispatches an event and records how many
superstate levels separate the active leaf from the handler that returned the
outcome. The blocking engine preserves its recursive before/after-dispatch hook
nesting. The awaitable engine preserves its iterative hook ordering and does not
box a recursive future.

The recorded value is a dispatch-path offset, not a superstate discriminant or
an absolute depth sampled around handler execution. It therefore continues to
identify the accepting occurrence when the same superstate variant appears
more than once, or when borrowed handler code changes the active hierarchy
before returning.

## Path selection

Legacy transitions continue to use the repository's existing
`StateExt::transition_path`, including leaf self-transition exit and entry.
Local transitions use that same shortest path for distinct leaf variants, but
select `(0, 0)` for the same leaf variant.

External transitions derive the accepting handler's hierarchy depth from the
active leaf depth and private handler offset. The usable boundary is the
shallower of:

- the active and target leaves' deepest common ancestor; and
- the accepting handler's parent.

This exits and re-enters an accepting superstate only when the target remains
within its subtree. A target outside the subtree follows the ordinary common
ancestor and does not retain an unrelated handler boundary.

## Transition transaction

All three kinds use the existing transaction: call the before-transition hook,
compute the action path, run exits, swap the active and target leaf exactly
once, run entries, and call the after-transition hook. Consequently a local
self-transition still installs new state-local storage and calls both hooks,
despite running no entry or exit action. Exit actions and hooks observe the old
leaf value; entry actions and the final hook observe the new value.

No macro syntax or generated handler representation changed. Macro-generated
handlers already forward arbitrary `Outcome<State>` values, so the new variants
work through root, mode-module, and prelude exports without macro-crate edits.
The README now documents legacy, local, and external choices with a nested
hierarchy and their different self-transition behavior.
