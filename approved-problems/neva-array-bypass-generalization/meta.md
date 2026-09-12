---
Repository: https://github.com/nevalang/neva
Issue: N/A
Commit: 939996ba4611ca6798026852cdb3b617a8bce84f
Language: Go
Category: feature-request
Title: Add chaining, fan-out and injected-dependency array-bypass connections
---
# Add chaining, fan-out and injected-dependency array-bypass connections

Every form the network supports for an ordinary connection has to work for an array-bypass connection too, including chains, fan-out, and a node standing in for an injected dependency.

A bypass links each used slot of its sender to the same numbered slot of every receiver. Either side of it may be the component's own array port, and the slot count comes from whatever the parent used for that port. A bypass between two nodes, where neither side is a port of the component itself, is a compile error reported at that connection.

The `sync` package also gains `WaitAll`, with an array inport `sig` and a single `sig` outport, emitting a signal once every used input slot has delivered a message, and again for each further round of messages.
