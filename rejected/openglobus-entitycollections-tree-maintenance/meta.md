---
Repository: https://github.com/openglobus/openglobus
Issue: N/A
Commit: 61757dbc79604e37b3e85192ca1945b94c982d2a
Language: TypeScript
Category: feature-request
Title: Add incremental maintenance to the Vector layer entity collections tree
---

# Add incremental maintenance to the Vector layer entity collections tree

Add insert and remove maintenance to the entity collections tree that a `Vector` layer keeps over its planet. Today the tree is only correct right after a bulk build: an entity handed to the strategy later is appended to the node the call started from rather than descending to the node that should hold it, `nodeCapacity` is never looked at again, and removing an entity leaves the counts of the nodes above it as they were.

After any mix of additions and removals the tree has to hold the invariants a bulk build gives it. An entity is held by exactly one node, that node's extent contains it, and that node has no children. No node holds more than `nodeCapacity` entities of its own, unless every one of them sits at the same position, where splitting could never separate them. Every node's `count` is the number of entities held at or below it. A node that holds nothing has no entity collection, and a node with nothing below it has no children, so it can take entities again. Every entity knows the node that holds it. When more than one child extent contains a position, the first of the north-west, north-east, south-west and south-east children takes it. All of this holds in each of the three trees the Earth strategy keeps and in both trees the Equi strategy keeps.

Add `getEntityCollectionsTreeStrategy()` to `Vector`, an instance method returning the layer's strategy, or `null` while the layer has no planet. Add two instance methods to `EntityCollectionsTreeStrategy`: `removeEntity(entity)`, which takes the entity out of the node holding it and returns whether the tree held it, and `getRootNodes()`, which returns the root nodes as an array, in the order mercator, north, south for the Earth strategy and west, east for the Equi strategy, and empty on the base class. `Vector.removeEntity` uses `removeEntity`.
