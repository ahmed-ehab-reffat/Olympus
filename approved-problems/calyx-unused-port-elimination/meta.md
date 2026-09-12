---
Repository: https://github.com/calyxir/calyx
Issue: N/A
Commit: cb25dcb8e5074915887048e2780e2c7bedcba4e8
Language: Rust
Title: Add whole-program elimination of unused component ports
---
# Add whole-program elimination of unused component ports

Add a `dead-port-elimination` pass: Calyx keeps every port a component declares even when nothing in the program can observe it.

The pass reasons about the whole program and removes a port only when doing so cannot change what the program computes: the values its entrypoint exposes, the contents any register or memory latches, and the state written into `ref` and `@external` cells. A value reaching any input of a stateful primitive counts as reaching that state, even when nothing reads that primitive back. An output port is unused when no instance of the component has it read. An input port is unused when the component never uses its value to affect any of that.

Removing a port also removes every assignment and every `invoke` binding that mentions it, wherever it lives; an `invoke` of a primitive cell counts exactly like an `invoke` of a component. An `fsm` block is part of a component's wiring too: the assignments inside its states and the guards on its transitions read and drive ports just like the assignments in a group. Because removing one thing can leave another unused, the pass reaches a fixed point over the whole program.

A non-interface port that always carries the same constant is also removed, and every reader uses that constant directly, a guard on an `fsm` transition included. The value has to hold in every cycle, on both sides.

For an input port, that means every instance is driven with that one constant the whole time it is live: a drive that only applies while some group or `fsm` state is active, or that is present at only some of the invokes activating an instance, does not qualify. A constant carried only by invoke bindings also stops qualifying once anything else starts that instance through its `@go`, be that structural wiring, an `fsm` state, or another `invoke` output bound to it, but an unconditional continuous drive still qualifies because it holds the value during every activation. For an output port, it means the component itself drives it with that one constant in every cycle. A port driven with a different constant, with a non-constant or guarded value, or left undriven at any of those points, stays. An output bound to a destination by an `invoke` also stays, because dropping that binding would lose the write it performs.

The entrypoint keeps its signature, and so does any component carrying a new `@fixed_signature` attribute. The `@go`, `@done`, `@clk` and `@reset` ports are always kept, and a value that drives one of them on an instance is live: dropping it would stop that instance from ever running.

A `ref` cell that its own component never mentions is dropped from the signature and from every `invoke` that binds it. Naming the cell anywhere in the component body counts as mentioning it, an `invoke` binding included. A binding counts only while it survives: once the callee-side `ref` it targets is itself dropped, that binding goes with it and stops being a mention, so a caller `ref` left with no other use is removed on a later round, the same way a caller input feeding only a dead callee input is.

Running with `-x dead-port-elimination:dump=<file>` writes a json array holding one object per component that lost something, each with a `component` name and sorted `ports` and `ref_cells` lists, ordered by component name.
