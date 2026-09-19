---
Repository: https://github.com/vivisect/vivisect
Issue: N/A
Commit: d5062e6f3cc525c9cc844673256233ec55e715c8
Language: Python
Category: bugfix
Title: Fix no-return analysis to verify and propagate call targets
---

# Fix no-return analysis to verify and propagate call targets

Fix the no-return analysis so it verifies why each path cannot fall back out. Only a genuine, unconditional trap or halt is evidence by itself: one that fires only on a condition leaves its fallthrough live, and a software interrupt carrying an operand is not self-evidently terminal. A transfer is not evidence merely because its decode flags say it cannot fall through, and nothing decoded after such a transfer belongs to the function. Running out of mapped code proves nothing, nor does memory that is not executable or not initialized.

A terminal path ending in a call, or in an unconditional jump that leaves the function, supports a no-return conclusion only when every destination it resolves to is itself proven no-return. A destination the instruction alone does not name is still resolved when the workspace has recorded a code reference from that site to it, however that reference is flagged. That includes a destination an instruction computes into the program counter, though an instruction that merely reads the program counter and stores it elsewhere transfers nothing and control carries on to the instruction behind it, whatever its decode flags say and even where disassembly stopped at that instruction and recorded nothing after it. A memory-indirect call resolves through its slot to the target actually stored there, unless the slot itself is a declared no-return address, which is then the destination.

A function is proven only when every path through it reaches something that settles it. A path continues past a call whose destinations are not all proven, since such a call may return. A function with a path that loops back to an already visited address remains return-capable, even if its other paths are settled.

Add a `propagateNoReturn` method returning the set of functions newly marked no-return. Every function not already known no-return is examined, including one settled by its own trap alone; this analysis never withdraws a conclusion already reached. Running it again once nothing new remains to be learned changes nothing, and it never invokes the rest of the analysis pipeline.

`addNoReturnVa` must re-derive every consequence of the declaration immediately, returning that same set. When a call site is marked no-flow because its target is no-return, retain all of that site's xrefs without duplicates so it remains discoverable as a caller.
