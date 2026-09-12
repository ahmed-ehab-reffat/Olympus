# Retired minor-version mutant

L4 mutant 26 changed the reference to accept SHB version 1.1 and expected
`MalformedFraming` to reject it. Fairness review established that this pins an
exclusive minor-version policy absent from both the repository and prompt.

The L5 prompt specifies only the supported major section version. The
reference checks major version 1 and preserves the minor field. The 1.1
rejection fixture and mutant 26 are removed rather than replaced with another
minor-version discriminator.

An audit-only probe changed a valid exact-copy fixture from SHB 1.0 to 1.1.
The L5 reference built, accepted the capture, preserved it, and passed. This
probe is recorded in `minor-version-compatibility.log`; it is not part of the
hidden suite.

The current attempted mutation set contains 30 active mutants: stable IDs
1-25, 27-31. All 30 compile and are killed. The ledger retains an explicit
retired line for ID 26 so historical identifiers are not silently renumbered.
