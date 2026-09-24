---
Repository: https://github.com/dyn4j/dyn4j
Issue: N/A
Commit: bcf942adaa9bfd32a1abd043cbc9021ab158d0ad
Language: Java
Category: feature-request
Title: Add deep copies of physics worlds that continue the simulation exactly
---

# Add deep copies of physics worlds that continue the simulation exactly

Add a `copy()` method to `World` that returns a deep copy of the whole simulation, and make `World` implement `Copyable`. Right now the only way to get a second world is to rebuild it from `Body.copy()` and the joints' `copy(...)` methods, and a world rebuilt that way drifts away from the original on its very first step.

The copy has to stand on its own. Nothing in it may reference the original world or any of the original's bodies, fixtures, joints, contacts, settings, gravity, bounds or time step, and changing or stepping either world afterwards never affects the other. Body i of the copy is the copy of body i of the original, and each copied joint joins the copies of its bodies. The detectors, solvers, filters and value mixer configured on the original are shared, but the copy never consults the original world for anything. Listeners and user data are not copied, the same as `copy()` on bodies and joints.

From the moment it is taken, the copy behaves exactly like the original would: making the same calls on both (`step`, `update`, `updatev` or anything else) produces bit-identical transforms, velocities and at-rest states, whatever the original went through before it was copied. The copy also reports the same collision data as the original, in the same order and with the same body first, and contact listeners added to the copy see the same events as listeners added to the original. The one exception is a step in which more than one body needs a time-of-impact correction, because the engine does not fix the order of those corrections itself.

If a body or joint in the world returns an object of a different class from its `copy()`, `World.copy()` throws the same `CopyException` dyn4j already raises when copying such a class.
