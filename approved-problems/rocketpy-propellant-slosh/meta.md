---
Repository: https://github.com/RocketPy-Team/RocketPy
Issue: N/A
Commit: 9bd6ad3af8f97bafa3201d4e70eba2877e66e040
Language: Python
Category: feature-request
Title: Add lateral propellant slosh to the rocket flight model
---

# Add lateral propellant slosh to the rocket flight model

Add lateral propellant slosh to both simulation modes of the flight model. Give every concrete tank class a `slosh` keyword taking a `TankSlosh` built from a `mass_ratio`, a `natural_frequency` in radians per second and a `damping_ratio`. Each is a number or a callable receiving the tank's fill fraction, its liquid volume over its total volume. A tank exposes the participating mass as `slosh_mass`, the mass ratio times the liquid mass, and a tank built without a slosh model reports zero there.

Each such tank contributes one slosh mode: a point mass free to move in the two body directions perpendicular to the rocket axis, held by a spring and damper of that natural frequency and damping ratio, and driven by the lateral body frame force on the rocket divided by the rocket's total mass. Gravity pulls alike on the mode and on the tank, so it does not enter that force. The mode is measured against the tank that carries it, so a lateral force on the rocket drives it the other way.

The slosh masses shift the vehicle centre of mass sideways by the sum over the modes of the participating mass times the mode displacement, divided by the rocket's total mass, and that offset has a rate and an acceleration formed the same way from the mode velocities and the mode accelerations. The six degree of freedom equations incorporate the offset, its rate and its acceleration. The three degree of freedom and parachute equations incorporate only its acceleration. On the rail the vehicle is held sideways, so nothing couples there. Selecting the legacy solid propulsion equations for a rocket that carries slosh modes raises a ValueError. `Flight` reports the offset as `lateral_center_of_mass_offset`, a pair of functions of time holding the two body directions in order, and reports each mode's motion the same way as `slosh_displacement` and `slosh_velocity`, lists holding one such pair per mode. Those lists are ordered the same way as `Rocket.slosh_modes`, which runs by the axial position of the owning tank in the rocket frame, ascending, with ties in the order the tanks were added.

The flight state appends four entries for every mode in that same order, the two displacements followed by the two velocities. A per-state solver tolerance supplied at the original width is padded to cover those entries, and an initial state supplied at the original width is padded the same way, with every mode at rest. An initial state that carries mode entries gives a block for every mode, and any other width raises a ValueError. The modes keep being integrated through every flight phase, and where a phase resolves no lateral body frame force, the driving term is zero.
