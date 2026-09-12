# go-mp4 sample-locations prototype preservation

Recorded: 2026-07-30

## Repository

- URL: `https://github.com/abema/go-mp4.git`
- Pinned commit: `7f0bb4060772e78fb52d48b73a38b8c3928e83f0`
- Preserved checkout: `work/go-mp4-sample-locations/probe`
- Patch: `prototype.patch`
- Patch SHA-256: `458615e6f2587981a8862ce4e0db2e24ba061908e8f6241b69e27006fcafdce5`

## Preserved state

The binary-capable patch captures the complete non-ignored dirty state:

- modified `probe.go`;
- untracked `sample_location_probe_test.go`; and
- 331 insertions and 81 deletions across both files.

This is the earlier feasibility prototype, not the canonical rejected-problem
solution. The durable problem artifacts, including `test.patch` and
`solution.patch`, remain under `problems/go-mp4-sample-locations/`.

The checkout remains in place at the user's request.

## Recovery

```sh
git clone https://github.com/abema/go-mp4.git work/go-mp4-sample-locations/recovered-prototype
git -C work/go-mp4-sample-locations/recovered-prototype checkout 7f0bb4060772e78fb52d48b73a38b8c3928e83f0
git -C work/go-mp4-sample-locations/recovered-prototype apply ../../../archive/go-mp4-sample-locations/prototype.patch
```
