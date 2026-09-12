# Environment preflight - portable cycle-exact Cider checkpoints

Date: 2026-07-25

Pinned source:
`264c618e3db8bab3d110a0c03ff44df3611e8990`

## Minimal official-image lane

The focused lane uses the official `rust:1.90-bookworm` image:

- digest:
  `sha256:3914072ca0c3b8aad871db9169a651ccfce30cf58303e5d6f2db16d1d8a7e58f`;
- image size: 517,436,652 bytes;
- Rust toolchain forced to installed `1.90.0`;
- source checkout mounted separately from caches; and
- all verification commands after warming use `--network none`,
  `CARGO_NET_OFFLINE=true`, `--locked`, and `--offline`.

Only dependencies declared by the pinned repository were warmed. The
repository Dockerfile also declares `runt` 0.4.1, which was installed into an
isolated tool volume for the declarative slice.

## Results

| Check | Result | Wall time |
|---|---:|---:|
| dependency fetch | pass | 114.71 s |
| Cider build, network disabled | pass | 23.68 s |
| `cargo test -p cider`, network disabled | 50 unit + 3 doc pass; 1 doc ignored | 9.60 s |
| `cider-data-converter` build, network disabled | pass | 6.70 s |
| declarative `unit` runt slice, network disabled | 6/6 pass | 0.33 s |

The `unit` slice invokes Cider directly on unlowered `.futil` programs. It
therefore exercises high-level group/control execution rather than only
fully-lowered programs.

## Cache and disk measurements

After the preflight:

| Isolated volume | Size |
|---|---:|
| Cargo registry | 702 MB |
| Cargo Git sources | 3.0 MB |
| target directory | 1.4 GB |
| `runt` tool root | 3.2 MB |

The full upstream clone is approximately 528 MB of Git data before build
artifacts. No generated fixture was required for the focused slice.

## Required and excluded tools

Required:

- official Rust 1.90 image;
- Cargo;
- POSIX shell utilities used by `runt`;
- `runt` 0.4.1; and
- `cider-data-converter`.

Not required by the focused lane:

- Verilator;
- Icarus Verilog;
- FPGA vendor tools;
- CIRCT/MLIR;
- native HDL simulators; or
- the Python `fud2` workflow.

The candidate therefore passes the minimal official-image and offline
preflight gate.
