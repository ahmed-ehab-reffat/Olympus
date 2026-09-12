---
Repository: https://github.com/gfx-rs/rspirv
Issue: N/A
Commit: 5550457c544718ffb31292b6174c084049f4b832
Language: Rust
Category: feature-request
Title: Add decoration group resolution to rspirv's debug representation
---

# Add decoration group resolution to rspirv's debug representation

Add decoration-group resolution to rspirv's debug representation. `dr::Module` currently stores
every decoration and group-apply instruction as a flat, unresolved list; nothing in the crate
expands the indirection a decoration group represents into the concrete decorations it
contributes to each of its targets.

Add a `resolve_decorations` function (and a `Module::resolve_decorations` convenience method)
returning a `ResolvedDecorations` value queryable with `for_target(id)` and `for_member(id,
member)`, each returning every decoration applying to that target or member: direct decorations
first in module order, then decorations contributed through group references in the order those
references appear, then in the order of the group's own decorations. Decorations reachable
through more than one channel are not deduplicated. When a group's decoration is expanded onto
a `(target, member)` pair, the result keeps the group decoration's original form (literal, id,
or string). An id counts as defined if it is the result id of any instruction anywhere in the
module, not only ones appearing earlier. A decoration produced by expanding a group reference is
included only when the referenced group is a declared decoration group and the specific target
(or target-member pair) it names resolves to a defined id; otherwise the reference is reported by
`ResolvedDecorations::unresolved()`, which returns a slice of `dr::UnresolvedReference`, an enum
with variants `UnknownGroup { group }`, `UnknownTarget { group, target }` and
`UnknownMemberTarget { group, target, member }` for an undeclared group, an undefined
whole-object target, and an undefined per-member target respectively. The same group id may be
referenced by more than one group-apply instruction within one module; every reference resolves
independently against that group's own decorations.

`ResolvedDecorations::conflicts()` returns a `Vec<DecorationConflict>` with public fields
`target: spirv::Word`, `member: Option<u32>`, `first: Instruction` and `second: Instruction`, one
entry per pair of resolved decorations sharing the same decoration kind on the same target or
member whose extra parameters disagree; same-kind decorations with identical parameters are
duplicates, not conflicts, and are not reported. `groups_contributing_to(id)` and
`groups_contributing_to_member(id, member)` list, in contribution order, the ids of every
declared group that added a decoration to that target or member through a group-apply
instruction (one entry per contributing instruction; a group with no decorations of its own
contributes no entry). `decorated_targets()` and `decorated_members()` list every target or
`(target, member)` pair with at least one resolved decoration, sorted ascending.
`unique_for_target(id)` and `unique_for_member(id, member)` return the same decorations as
`for_target`/`for_member` with exact duplicates collapsed to their first occurrence, preserving
order.

Add a `binary::disassemble_decorations` function rendering a module's resolved decorations as
text: one `%<id>: <decorations>` line per target from `decorated_targets()`, in that order,
followed by one `%<id>.<member>: <decorations>` line per pair from `decorated_members()`, in that
order, each target's or member's decorations joined by `" | "`. Targets are listed before
members. After those lines, append one comment per entry from `unresolved()`, in that slice's
order: `"; unresolved: group %<group> is not a declared decoration group"` for `UnknownGroup`,
`"; unresolved: group %<group> references undefined target %<target>"` for `UnknownTarget`, and
`"; unresolved: group %<group> references undefined member %<target>.<member>"` for
`UnknownMemberTarget`.
