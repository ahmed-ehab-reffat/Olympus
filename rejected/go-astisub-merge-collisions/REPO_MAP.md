# REPO MAP - asticode/go-astisub

Last verified: 2026-08-01 at `52190f1d606f35190d40e86ecb02c31902f30272`.

| Purpose | Command | Offline constraints |
|---|---|---|
| Existing suite | `go test ./...` | Warm committed modules; network disabled |
| Race | `go test -race ./...` | Supported in Go image |
| Static | `go vet ./...` and `gofmt` | No downloads |
| Focused | `go test ./... -run MergeCollision` | In-memory fixtures |

| Subsystem | Entry point | Files | Oracle |
|---|---|---|---|
| Merge graph | `(*Subtitles).Merge` | `subtitles.go` | Public graph and stable order |
| TTML | `ReadFromTTML`, `WriteToTTML` | `ttml.go` | Complete named-edge round trip |
| SSA | read/write SSA | `ssa.go` | Native named styles |
| WebVTT | read/write WebVTT | `webvtt.go` | Native regions/settings |

The current flow appends donor item pointers, stable-sorts, then unions region
and style maps while silently skipping duplicate IDs. Writers emit reference
IDs separately from map definitions, exposing a semantic mismatch after reopen.

Hazards: maps are unordered; item/line slices and pointer graphs alias donor
state; formats have different representational limits. Tests must not assert
pointer topology, suffix spelling, malformed graphs, or cross-format features.

