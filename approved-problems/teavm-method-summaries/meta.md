---
Repository: https://github.com/konsoletyper/teavm
Issue: N/A
Commit: fd78e03fca45fc76d5454f2940a3b200b221959f
Language: Java
Category: feature-request
Title: Add whole-program method summaries to the TeaVM optimizer
---

# Add whole-program method summaries to the TeaVM optimizer

Add whole-program method summaries to TeaVM so that the per-method optimizer stops treating every call as opaque. Today each method is optimized on its own: the result of a call is never known to be non-null, and `RepeatedFieldReadElimination` forgets every cached field read at any call.

Add `org.teavm.model.analysis.MethodSummaries`, created by a static `MethodSummaries.build(ListableClassReaderSource classes)` over the classes of a build. It answers `neverReturnsNull(InvocationType type, MethodReference method)` and `getWrittenFields(InvocationType type, MethodReference method)` for a call, and `getInitializerWrittenFields(String className)` for an `initClass` instruction. A written-field set holds `FieldReference`s, static or instance, exactly as the storing instruction names them; `null` means the call may write any field.

A `SPECIAL` call runs the method the class set resolves for that reference, looking up through superclasses. A `VIRTUAL` call can run, for the called class and every non-abstract class in the set that is a subtype of it, the implementation an instance of that class would run. A call never returns null only when none of the methods it can run can, and it writes everything they write. A method without a body (native, or a class or method the set does not contain) is unknown, and an `invokedynamic` instruction counts as a call to an unknown method. A call to an unknown method may return null and may write any field, and so may every method that makes one.

A method writes the fields its own instructions store to, whatever its calls write, and, for each `initClass` instruction, whatever that class's `<clinit>` writes: nothing when the class has no `<clinit>`, anything when the class is not in the set. A method returning a reference never returns null when `NullnessInformation`, given these summaries, proves every value it returns non-null. The facts are the most precise ones that hold for all methods at once, so recursion and mutual recursion lose nothing by themselves.

`NullnessInformation.build(Program, MethodDescriptor, MethodSummaries)` treats the result of a call that never returns null as non-null; the two-argument form stays as it is. `MethodOptimizationContext` gets a default `getMethodSummaries()` returning `null`. `RedundantNullCheckElimination`, `ConstantConditionElimination` and `LoopInvariantMotion` hand it to the nullness analysis, and when it is not `null`, `RepeatedFieldReadElimination` keeps cached reads across a call or an `initClass` and forgets only the fields that call or initializer may write. With `null` summaries every pass behaves as it does today. At every optimization level, `TeaVM` builds the summaries before it optimizes any method and passes them to every method it optimizes.
