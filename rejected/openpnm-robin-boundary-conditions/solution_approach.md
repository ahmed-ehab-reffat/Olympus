# Solution approach - OpenPNM Robin boundary conditions

The reference represents each Robin condition as paired external-value and
coefficient state managed through the existing boundary-condition lifecycle.
During construction of the working linear system, it adds the coefficient to
the selected diagonal and the coefficient times the external value to the right
hand side. The pure cached system is left unchanged.

Topology validation treats a positive finite Robin condition as a physical
anchor. Reactive transport accumulates the masks of every boundary kind before
allowing sources, preserving mutual exclusion after the new kind is added.
Transient algorithms inherit the same system update and therefore need no
separate time-integration implementation for static conditions.
