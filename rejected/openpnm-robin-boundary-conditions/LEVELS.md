# Levels - OpenPNM Robin boundary conditions

Target: 1-5 solves in 10 platform runs, with successful medians of at least two
production files, 20 platform-reported agent messages, and 200 strict effective
production LOC.

| Version | Change | Local estimate | Platform | Verdict |
|---|---|---:|---:|---|
| v1 | Initial locally verified static Robin BC package | not run | 0/10 | superseded after a false-positive mutant silently resized mismatched vectors |
| v2 | Added the public per-pore input-length discriminator | 2/2 solves | 0/10 | closed as too easy and too small |

Both v2 attempts were cold `gpt-5.6-sol` runs against only the public prompt.
They passed 15/15 focused tests and their full base lanes. Successful patches
changed two production files each, but only 101 and 82 raw production lines.
Their 91.5-line median cannot reach the 200 strict-effective-LOC floor.

No v3 is planned. The trajectories show complete, repository-native solutions
rather than a shared incorrect shortcut. More Robin fixtures would duplicate
existing algebra, lifecycle, topology, reactive, transient, or cache
discriminators. Broadening into another transport feature solely to increase
size would be padding. Platform calibration remains 0/10 permanently.
