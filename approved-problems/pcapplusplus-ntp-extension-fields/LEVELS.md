# Level assessment

Accepted level: **final version 6, accepted 2026-08-06**.

The implementation footprint is moderate, but the difficulty comes from
resolving a genuinely ambiguous NTPv4 tail without regressing authentication,
then making edits safe in both detached and packet-attached storage. A shallow
implementation can parse ordinary fields and still mishandle field-free
extension-shaped authentication, short non-final fields, malformed boundaries,
duplicates, atomic authenticated edits, or the existing NTPv3/classifier paths.

The task remains bounded: two production files, no new dependency, and a
compact public API. The prompt gives exact wire and editing rules, so success
depends on integrating those rules rather than discovering a private algorithm.
The five locally retained Nova runs are design and hardening evidence rather
than a complete platform calibration batch. Acceptance is user-confirmed; no
unreported solve count is reconstructed from that outcome. Raw run evidence is
archived under `archive/pcapplusplus-ntp-extension-fields/`.
