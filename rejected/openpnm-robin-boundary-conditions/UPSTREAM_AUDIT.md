# Upstream audit - OpenPNM Robin boundary conditions

Audit date: 2026-08-01

Frozen pin and current default-branch head:
`86d9855f7799a5523dd9e579ba94693d3caa27ec`.

GitHub all-state issue and pull-request searches were repeated for `robin`,
`mixed boundary`, `third kind`, `film coefficient`, and `convective boundary`.
Every exact search returned zero items. `git ls-remote` confirmed that the
candidate pin remains the upstream `dev` head. Local source, fetched refs,
history, candidate records, problem records, and archives contain no matching
implementation or submission.

Issue 1766 concerns time-varying boundary values and issue 2486 concerns
residual invading-phase behavior. Neither owns static linear exchange between
an external value and the current scalar pore value.

Result: no upstream ownership collision found for the frozen version. Repeat
this audit if the pin or public contract changes.
