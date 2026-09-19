---
Repository: https://github.com/featurevisor/featurevisor
Issue: N/A
Commit: b88f3981989c3cc7a06efea2597807517a624d16
Language: TypeScript
Category: feature-request
Title: Add sound pruning to datafiles built for a Target context
---

# Add sound pruning to datafiles built for a Target context

Add real specialization to the datafiles built for a Target that has a `context`, through `applyContextToDatafile`. Today it folds any condition that happens to match the Target context into `*` and leaves the rest in place. A condition on an attribute the Target never mentions can be folded, because `notEquals` and `notExists` match an absent attribute. A negative condition the Target makes false stays in the file and matches at runtime. Rules meant for other Targets are never removed.

A Target datafile is evaluated at runtime with contexts that leave out the attributes the Target fixes. For any such runtime context, every flag, variation, feature variable and global variable must evaluate exactly as the full datafile does when the Target context is added to the runtime context.

A condition is decided at build time only when the Target context has a value at the condition's attribute path, dotted paths included. Every other condition stays for runtime. Fold what the Target decides: a decided condition, and a segment whose conditions the Target decides, is replaced by its outcome in every expression that uses it. Segments, `and`, `or`, `not` and condition lists keep the meaning the SDK gives them, empty ones included. Selectors may arrive stringified in any form the builder writes today, scalar JSON included.

Then prune every ordered list the SDK searches for its first match: feature `force` entries, traffic rules, rule and variation `variableOverrides`, and global variable `overrides`. Remove each entry the Target can never match, and each entry that comes after one it always matches. Judge each kind of entry by the rule the SDK uses to match that kind. An entry with `requiredFeatures` can never be known to match at build time, though it can still be known never to match.

Finally, the Target datafile keeps exactly the segments that its remaining entries still reference.
